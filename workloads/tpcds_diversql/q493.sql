WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        t.t_meal_time,
        t.t_sub_shift,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        c.c_birth_month,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_promo_sk,
        p.p_promo_name
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        t.t_meal_time = 'lunch'
        AND t.t_sub_shift = 'afternoon'
        AND c.c_birth_month = 6
        AND c.c_preferred_cust_flag = 'Y'
        AND p.p_discount_active = 'Y'
        AND ib.ib_upper_bound >= 50000
        AND cs.cs_promo_sk IN (SELECT DISTINCT p2.p_promo_sk FROM promotion p2 WHERE p2.p_discount_active = 'Y')
),
returns_agg AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        COUNT(*) AS cnt_store_returns
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_meal_time = 'lunch'
    GROUP BY sr.sr_customer_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        COUNT(*) AS cnt_web_sales
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_meal_time = 'lunch'
      AND EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_return_amt > 100
      )
    GROUP BY ws.ws_bill_customer_sk
),
inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
),
combined AS (
    SELECT
        s.cs_warehouse_sk,
        w.w_warehouse_name,
        s.cs_sold_date_sk,
        s.t_meal_time,
        s.c_first_name,
        s.c_last_name,
        s.cd_gender,
        s.p_promo_name,
        s.cs_ext_sales_price,
        s.cs_net_profit,
        COALESCE(r.total_store_return_amt, 0) AS cust_store_return_amt,
        COALESCE(ws.total_web_net_paid, 0) AS cust_web_net_paid,
        i.total_on_hand,
        RANK() OVER (PARTITION BY s.cs_warehouse_sk ORDER BY s.cs_net_profit DESC) AS profit_rank,
        COUNT(*) OVER (PARTITION BY s.cs_warehouse_sk) AS warehouse_row_cnt,
        (
            SELECT SUM(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = s.c_customer_sk
              AND sr2.sr_return_quantity > 1
        ) AS corr_store_ret_sum
    FROM sales_agg s
    JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN returns_agg r ON s.c_customer_sk = r.sr_customer_sk
    LEFT JOIN web_sales_agg ws ON s.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN inventory_agg i ON s.cs_warehouse_sk = i.inv_warehouse_sk
    WHERE s.cs_net_profit > 0
      AND i.total_on_hand IS NOT NULL
)
SELECT DISTINCT
    cs_warehouse_sk,
    w_warehouse_name,
    cs_sold_date_sk,
    t_meal_time,
    c_first_name,
    c_last_name,
    cd_gender,
    p_promo_name,
    cs_ext_sales_price,
    cs_net_profit,
    cust_store_return_amt,
    corr_store_ret_sum,
    cust_web_net_paid,
    total_on_hand,
    profit_rank
FROM combined
WHERE warehouse_row_cnt >= 5
ORDER BY cs_warehouse_sk, profit_rank
LIMIT 100
