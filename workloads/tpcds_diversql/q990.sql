WITH exclusive_store_items AS (
    SELECT ss_item_sk
    FROM store_sales
    EXCEPT
    SELECT ws_item_sk
    FROM web_sales
),
filtered AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_product_name,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_state,
        hd.hd_income_band_sk,
        ws.ws_quantity,
        r.r_reason_desc,
        (
            SELECT COUNT(*)
            FROM web_returns wr2
            WHERE wr2.wr_reason_sk = r.r_reason_sk
        ) AS reason_return_cnt,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_profit DESC) AS rn
    FROM store_sales ss
    JOIN exclusive_store_items esi ON ss.ss_item_sk = esi.ss_item_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN inventory inv TABLESAMPLE BERNOULLI (10) ON inv.inv_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_current_price > 100
      AND ss.ss_net_profit > 0
      AND c.c_birth_year BETWEEN 1950 AND 1980
      AND inv.inv_quantity_on_hand < 500
      AND ca.ca_state IN ('CA','NY','TX')
      AND r.r_reason_desc LIKE '%time%'
      AND c.c_customer_sk IN (SELECT ss_customer_sk FROM store_sales WHERE ss_quantity > 2)
)
SELECT
    i_category,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(ss_net_profit) AS category_profit,
    AVG(i_current_price) AS avg_price,
    SUM(reason_return_cnt) AS total_returns_for_reason
FROM filtered
WHERE rn <= 3
GROUP BY i_category
ORDER BY category_profit DESC
LIMIT 10
