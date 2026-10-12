WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_list_price,
        cs.cs_ext_ship_cost,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_color,
        sm.sm_type,
        ca_bill.ca_state           AS bill_state,
        ca_ship.ca_state           AS ship_state,
        inv.inv_quantity_on_hand,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        st.s_store_id,
        st.s_state                 AS store_state,
        ca_ret.ca_state            AS return_addr_state
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
    WHERE cs.cs_ext_list_price > 5000
      AND cs.cs_ext_ship_cost < 500
      AND ca_bill.ca_state = 'CA'
      AND i.i_category = 'Sports'
      AND sr.sr_returned_date_sk BETWEEN 2451900 AND 2452600
),
joined AS (
    SELECT
        b.s_store_id,
        b.i_category,
        b.i_brand,
        b.cs_ext_list_price,
        b.cs_net_profit,
        b.sr_net_loss,
        CASE WHEN b.cs_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
        ld.avg_discount,
        ROW_NUMBER() OVER (PARTITION BY b.s_store_id ORDER BY b.cs_net_profit DESC) AS profit_rank
    FROM base b
    CROSS JOIN LATERAL (
        SELECT avg(cs2.cs_ext_discount_amt) AS avg_discount
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = b.cs_item_sk
    ) ld
),
sales_agg AS (
    SELECT s_store_id,
           i_category,
           SUM(cs_net_profit)          AS total_profit,
           NULL                         AS total_return_loss,
           'sales'                      AS src
    FROM joined
    GROUP BY GROUPING SETS ((s_store_id, i_category), ())
),
returns_agg AS (
    SELECT s_store_id,
           i_category,
           NULL                         AS total_profit,
           SUM(sr_net_loss)            AS total_return_loss,
           'returns'                    AS src
    FROM joined
    GROUP BY GROUPING SETS ((s_store_id, i_category), ())
),
union_agg AS (
    SELECT * FROM sales_agg
    UNION DISTINCT
    SELECT * FROM returns_agg
),
except_keys AS (
    SELECT s_store_id, i_category FROM sales_agg
    EXCEPT
    SELECT s_store_id, i_category FROM returns_agg
),
intersect_keys AS (
    SELECT s_store_id, i_category FROM sales_agg
    INTERSECT
    SELECT s_store_id, i_category FROM returns_agg
)
SELECT ua.s_store_id,
       ua.i_category,
       ua.total_profit,
       ua.total_return_loss,
       ua.src,
       CASE WHEN ik.s_store_id IS NOT NULL THEN 1 ELSE 0 END AS in_intersect,
       CASE WHEN ek.s_store_id IS NOT NULL THEN 1 ELSE 0 END AS in_except
FROM union_agg ua
LEFT JOIN intersect_keys ik
  ON ua.s_store_id = ik.s_store_id AND ua.i_category = ik.i_category
LEFT JOIN except_keys ek
  ON ua.s_store_id = ek.s_store_id AND ua.i_category = ek.i_category
ORDER BY ua.total_profit DESC NULLS LAST,
         ua.total_return_loss DESC NULLS LAST
LIMIT 100
