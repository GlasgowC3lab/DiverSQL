WITH base AS (
    SELECT
        s.s_store_name,
        r.r_reason_desc,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        SUM(sr.sr_net_loss) AS total_sr_net_loss,
        SUM(wr.wr_net_loss) AS total_wr_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(i.i_current_price) AS avg_item_price,
        MIN(inv.inv_quantity_on_hand) AS min_inventory,
        MAX(w.w_warehouse_sq_ft) AS max_warehouse_sqft
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    JOIN reason r3
        ON wr.wr_reason_sk = r3.r_reason_sk
    JOIN customer_demographics cd_wr
        ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
    JOIN customer_address ca_wr
        ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
       AND w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE s.s_state = 'CA'
      AND w.w_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND r.r_reason_desc LIKE '%damage%'
    GROUP BY s.s_store_name, r.r_reason_desc, i.i_category
)
SELECT *
FROM base
ORDER BY total_cr_net_loss DESC
OFFSET 0 LIMIT 100
