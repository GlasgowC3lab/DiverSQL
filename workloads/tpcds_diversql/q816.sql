WITH base_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        ws.ws_ext_tax
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450915
      AND ws.ws_quantity > 1
      AND ws.ws_ext_sales_price > 100
      AND ws.ws_net_profit IS NOT NULL
),
joined AS (
    SELECT
        bs.ws_order_number,
        bs.ws_sold_date_sk,
        i.i_item_id,
        i.i_color,
        i.i_formulation,
        i.i_current_price,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        bs.ws_quantity,
        bs.ws_ext_sales_price,
        bs.ws_net_profit
    FROM base_sales bs
    JOIN item i ON bs.ws_item_sk = i.i_item_sk
    JOIN customer c ON bs.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON bs.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON bs.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
),
expanded AS (
    SELECT
        j.*, word
    FROM joined j
    CROSS JOIN UNNEST(regexp_split(j.i_item_desc, '\\s+')) AS t(word)
),
ranked AS (
    SELECT
        e.*,
        ROW_NUMBER() OVER (PARTITION BY e.i_item_id ORDER BY e.ws_ext_sales_price DESC) AS sales_rank,
        LAG(e.ws_ext_sales_price) OVER (PARTITION BY e.i_item_id ORDER BY e.ws_ext_sales_price DESC) AS prev_sales_price,
        CASE
            WHEN e.ws_ext_sales_price > 2 * COALESCE(LAG(e.ws_ext_sales_price) OVER (PARTITION BY e.i_item_id ORDER BY e.ws_ext_sales_price DESC), 0) THEN 'High Jump'
            ELSE 'Normal'
        END AS sales_category
    FROM expanded e
),
final AS (
    SELECT
        r.ws_order_number,
        r.ws_sold_date_sk,
        r.i_item_id,
        r.i_color,
        r.i_formulation,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_marital_status,
        r.hd_buy_potential,
        r.ib_lower_bound,
        r.ib_upper_bound,
        r.inv_quantity_on_hand,
        r.ws_quantity,
        r.ws_ext_sales_price,
        r.ws_net_profit,
        r.sales_rank,
        r.prev_sales_price,
        r.sales_category,
        r.word
    FROM ranked r
    WHERE r.sales_category = 'High Jump'
)
SELECT *
FROM final
EXCEPT
SELECT *
FROM final
WHERE sales_rank > 10
ORDER BY ws_ext_sales_price DESC, ws_order_number
LIMIT 100
