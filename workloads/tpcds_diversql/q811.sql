WITH
sales_agg AS (
    SELECT
        ss_store_sk AS store_sk,
        ss_item_sk AS item_sk,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_quantity) AS total_qty,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450500
      AND ss_ext_tax > 5
      AND ss_net_paid > 0
    GROUP BY ss_store_sk, ss_item_sk
),
returns_agg AS (
    SELECT
        sr_store_sk AS store_sk,
        sr_item_sk AS item_sk,
        SUM(sr_return_amt) AS total_returns,
        SUM(sr_return_quantity) AS total_return_qty
    FROM store_returns
    WHERE sr_return_amt > 0
      AND sr_return_quantity > 0
    GROUP BY sr_store_sk, sr_item_sk
),
inventory_agg AS (
    SELECT
        inv_item_sk AS item_sk,
        SUM(inv_quantity_on_hand) AS on_hand_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
),
joined_data AS (
    SELECT
        st.s_store_id,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        inv.on_hand_qty,
        s.total_profit,
        CASE
            WHEN s.total_profit > 0 THEN 'Profitable'
            ELSE 'Loss'
        END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY st.s_store_id ORDER BY s.total_profit DESC) AS rk
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.store_sk = r.store_sk
        AND s.item_sk = r.item_sk
    JOIN inventory_agg inv
        ON s.item_sk = inv.item_sk
    JOIN item i
        ON s.item_sk = i.i_item_sk
    JOIN store st
        ON s.store_sk = st.s_store_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    WHERE st.s_floor_space > 8000000
      AND st.s_geography_class = 'Unknown'
      AND i.i_current_price BETWEEN 10 AND 500
      AND p.p_purpose = 'Unknown'
      AND p.p_channel_radio = 'N'
      AND p.p_discount_active = 'N'
)
SELECT
    s_store_id,
    i_item_id,
    i_product_name,
    p_promo_name,
    total_sales,
    total_returns,
    on_hand_qty,
    profit_flag,
    total_profit
FROM joined_data
WHERE rk <= 5
ORDER BY s_store_id, rk
LIMIT 100
