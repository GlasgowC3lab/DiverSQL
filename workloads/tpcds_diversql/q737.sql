/* Goal: Identify top‑selling items by category with sales trends, vehicle ownership segment, and price‑per‑unit analysis, while preserving inventory rows that lack matching items and sales rows that lack matching inventory. */
WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10 % of rows for performance
),
joined_base AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_quantity_on_hand,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ca.ca_state,
        ca.ca_gmt_offset,
        s.s_store_name,
        s.s_state AS store_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM inventory inv
    FULL OUTER JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN sampled_sales ss
        ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
),
filtered AS (
    SELECT
        i_item_id,
        i_brand,
        i_category,
        s_store_name,
        ca_state,
        ss_sold_date_sk,
        ss_quantity,
        ss_sales_price,
        hd_vehicle_count,
        i_current_price,
        ca_gmt_offset,
        hd_dep_count,
        SUM(ss_quantity) OVER (PARTITION BY i_item_id) AS total_quantity
    FROM joined_base jb
    WHERE jb.ss_sold_date_sk BETWEEN 2450836 AND 2450955          -- filter 1: date range (surrogate keys)
      AND jb.ss_quantity > 0                                    -- filter 2: positive quantity sold
      AND jb.i_current_price > 20.00                            -- filter 3: price threshold
      AND jb.ca_gmt_offset BETWEEN -7.00 AND -5.00             -- filter 4: timezone offset range
      AND jb.hd_dep_count >= 3                                 -- filter 5: household dependent count
),
final AS (
    SELECT
        f.i_item_id,
        f.i_brand,
        f.i_category,
        f.s_store_name,
        f.ca_state,
        f.ss_sold_date_sk,
        f.ss_quantity,
        f.ss_sales_price,
        f.total_quantity,
        CASE WHEN f.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_segment,
        RANK() OVER (PARTITION BY f.i_category ORDER BY f.total_quantity DESC) AS category_quantity_rank,
        LAG(f.ss_quantity) OVER (PARTITION BY f.i_item_id ORDER BY f.ss_sold_date_sk) AS prev_quantity,
        SUM(f.ss_sales_price) OVER (PARTITION BY f.i_item_id ORDER BY f.ss_sold_date_sk
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales,
        lp.price_per_unit
    FROM filtered f
    CROSS JOIN LATERAL (
        SELECT f.ss_sales_price / NULLIF(f.ss_quantity, 0) AS price_per_unit
    ) lp
)
SELECT
    i_item_id,
    i_brand,
    i_category,
    s_store_name,
    ca_state,
    ss_sold_date_sk,
    ss_quantity,
    ss_sales_price,
    total_quantity,
    vehicle_segment,
    category_quantity_rank,
    prev_quantity,
    running_sales,
    price_per_unit
FROM final
ORDER BY running_sales DESC
LIMIT 100
