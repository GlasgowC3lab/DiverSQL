WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_promo_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450927 AND 2451053
),
promo_active AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE p.p_start_date_sk <= 2451053
      AND p.p_end_date_sk >= 2450927
      AND p.p_discount_active = 'Y'
),
item_filtered AS (
    SELECT i.i_item_sk, i.i_category, i.i_class, i.i_brand, i.i_current_price
    FROM item i
    WHERE i.i_brand = 'brandbrand #4'
      AND i.i_class = 'dresses'
),
inventory_filtered AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    WHERE inv.inv_warehouse_sk IN (1, 9, 10)
      AND inv.inv_date_sk = 2450927
    GROUP BY inv.inv_item_sk
    HAVING SUM(inv.inv_quantity_on_hand) > 200
)
SELECT
    agg.s_store_name,
    agg.i_category,
    agg.sold_month,
    agg.total_quantity,
    agg.total_profit,
    agg.avg_discount,
    RANK() OVER (PARTITION BY agg.i_category ORDER BY agg.total_profit DESC) AS profit_rank
FROM (
    SELECT
        s.s_store_name,
        i.i_category,
        date_format(date_add('day', ss.ss_sold_date_sk, DATE '1970-01-01'), '%Y-%m') AS sold_month,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM filtered_sales ss
    JOIN promo_active pa ON ss.ss_promo_sk = pa.p_promo_sk
    JOIN item_filtered i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory_filtered invf ON ss.ss_item_sk = invf.inv_item_sk
    GROUP BY s.s_store_name, i.i_category, date_format(date_add('day', ss.ss_sold_date_sk, DATE '1970-01-01'), '%Y-%m')
    HAVING SUM(ss.ss_net_profit) > 1000
) agg
ORDER BY agg.i_category, profit_rank
LIMIT 100
