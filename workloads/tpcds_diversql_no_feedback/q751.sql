WITH sales_returns AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    cs.cs_net_profit,
    cr.cr_net_loss,
    ca_refunded.ca_address_id,
    ca_refunded.ca_city,
    ca_refunded.ca_state,
    ca_refunded.ca_street_type,
    ca_refunded.ca_street_name,
    regexp_extract(ca_refunded.ca_address_id, '^([A-Z0-9]{3})', 1) AS addr_prefix,
    concat(ca_refunded.ca_city, ', ', ca_refunded.ca_state) AS location,
    split(ca_refunded.ca_street_name, ' ') AS street_name_parts
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  WHERE regexp_like(ca_refunded.ca_city, '^[A-Z]{2,}$')
    AND ca_refunded.ca_street_type LIKE '%Street%'
)
SELECT
  sr.cs_warehouse_sk AS warehouse,
  sum(sr.cs_net_profit) AS total_sales_profit,
  sum(sr.cr_net_loss) AS total_return_loss,
  count(DISTINCT sr.cs_order_number) AS distinct_orders,
  max(sr.location) AS sample_location,
  max(sr.addr_prefix) AS sample_addr_prefix,
  count(t.street_part) AS total_street_name_parts
FROM sales_returns sr
CROSS JOIN UNNEST(sr.street_name_parts) AS t(street_part)
GROUP BY sr.cs_warehouse_sk
ORDER BY total_return_loss DESC
LIMIT 100
