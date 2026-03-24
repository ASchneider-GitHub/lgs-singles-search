#!/bin/bash
# Requires `jq`

CARD_NAME="${*}"

if [ -z "$CARD_NAME" ]; then
    echo "Usage: cprice <CARD_NAME>"
    exit 1
fi

TARGET_VENDOR=("retrosharkgaming" "goingaming" "redcastle")
PAYLOAD=$(jq -n --arg name "$CARD_NAME" '{
  query: $name,
  context: {productLineName: "Magic: The Gathering"},
  filters: {productTypeName: ["Cards"]},
  from: 0,
  size: 24
}')

declare -A MAPPED_VENDOR_NAMES
MAPPED_VENDOR_NAMES=(
  ["retrosharkgaming"]="Retro Shark Gaming"
  ["redcastle"]="Red Castle"
  ["goingaming"]="Goin' Gaming"
)

{
  for URL in "${TARGET_VENDOR[@]}"; do
    VENDOR_NAME=${MAPPED_VENDOR_NAMES[$URL]:-$URL}

    SEARCH_DATA=$(curl -s "https://$URL.tcgplayerpro.com/api/catalog/search" \
      -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
      -H 'content-type: application/json' \
      --data-raw "$PAYLOAD")

    JOINED_SKU_IDS=$(echo "$SEARCH_DATA" | jq -r '.products.items[].id' | paste -sd, -)

    if [ -n "$JOINED_SKU_IDS" ]; then
      curl -s "https://$URL.tcgplayerpro.com/api/inventory/skus?productIds=$JOINED_SKU_IDS" \
	-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' | \
      jq -r --arg vendor "$VENDOR_NAME" \
            --arg base "https://$URL.tcgplayerpro.com/catalog/magic" \
            --argjson search "$SEARCH_DATA" '
        ( $search.products.items | reduce .[] as $item ({}; .[($item.id|tostring)] = {name: $item.name, path: ($item.setUrlName + "/" + $item.productUrlName + "/" + ($item.id|tostring))}) ) as $catalog |

        .[].skus[] |
        [
          $vendor,
          $catalog[.productId|tostring].name,
          .conditionName,
          ((.price * 100 | round / 100) | tostring | if contains(".") then . + "00" | .[0:index(".")+3] else . + ".00" end),
          .quantity,
          (if .isFoil then "Foil" else "Non-Foil" end),
          ($base + "/" + $catalog[.productId|tostring].path)
        ] | @tsv' | \
      sort -t$'\t' -k4,4n
      
      echo "---CHUNK_DELIMITER---"
    fi
  done
} | \
awk -F'\t' -v title="SEARCH: $CARD_NAME" '
  BEGIN {
    w[1]=35; w[2]=25; w[3]=10; w[4]=5; w[5]=10; w[6]=160 
    for(i=1; i<=6; i++) {
      dash=""; for(j=1; j<=w[i]+2; j++) dash=dash"-"
      border=border "+" dash
    }
    border=border"+"
    
    t_lid = border; gsub(/./, "-", t_lid);
    t_lid = "+" substr(t_lid, 2, length(t_lid)-2) "+"
    t_inner_w = length(border) - 4

    print t_lid
    printf "| %-*s |\n", t_inner_w, title
    print border
    printf "| %-35s | %-25s | %-10s | %-5s | %-10s | %-160s |\n", "CARD NAME", "CONDITION", "PRICE", "QTY", "FOIL", "URL"
    print border
    
    has_data = 0
  }

  # New store detected
  $1 != current_vendor && $1 != "---CHUNK_DELIMITER---" {
    # If this is NOT the first store we have found, print a separator line first
    if (has_data == 1) {
        print border
    }
    
    has_data = 1
    current_vendor = $1

    # Print the Store Header row
    printf "| %-*s |\n", t_inner_w, "STORE: " current_vendor
    print border
  }

  $1 == "---CHUNK_DELIMITER---" { next }

  NF > 0 {
    printf "| %-35.35s | %-25.25s | %-10s | %-5s | %-10s | %-160s |\n", $2, $3, $4, $5, $6, $7
  }

  END {
    if (has_data == 0) {
        printf "| %-*s |\n", t_inner_w, "  No results found at target vendors."
    }
    print border
  }
'
