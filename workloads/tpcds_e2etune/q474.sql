WITH latest_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
),

sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        ca.ca_state,
        td.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451100 AND 2451200
    GROUP BY cs.cs_item_sk, ca.ca_state, td.t_hour
),

returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        ca.ca_state,
        td.t_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_reason_sk IN (51, 50)
      AND cr.cr_returned_date_sk BETWEEN 2451100 AND 2451200
    GROUP BY cr.cr_item_sk, ca.ca_state, td.t_hour
)

SELECT
    i.i_category,
    agg.ca_state,
    agg.t_hour,
    agg.total_sales,
    agg.total_quantity,
    agg.total_profit,
    r.total_return_amount,
    r.total_return_quantity,
    r.total_return_loss,
    (r.total_return_quantity * 1.0 / NULLIF(agg.total_quantity, 0)) AS return_qty_ratio,
    inv.inv_quantity_on_hand,
    RANK() OVER (PARTITION BY agg.ca_state ORDER BY r.total_return_loss DESC) AS loss_rank_state,
    RANK() OVER (ORDER BY r.total_return_loss DESC) AS overall_loss_rank
FROM sales_agg agg
JOIN returns_agg r
  ON agg.item_sk = r.item_sk
 AND agg.ca_state = r.ca_state
 AND agg.t_hour = r.t_hour
JOIN item i ON agg.item_sk = i.i_item_sk
JOIN latest_inventory inv ON i.i_item_sk = inv.inv_item_sk
WHERE i.i_brand = 'BrandX'
  AND i.i_category IS NOT NULL
ORDER BY overall_loss_rank
LIMIT 10
