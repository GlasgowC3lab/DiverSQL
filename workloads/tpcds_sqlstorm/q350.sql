WITH
sales AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        st.s_state AS state,
        i.i_category AS category,
        i.i_brand AS brand,
        c.c_preferred_cust_flag AS pref_cust_flag,
        p.p_discount_active AS discount_active,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS uniq_customers,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, st.s_state, i.i_category, i.i_brand, c.c_preferred_cust_flag, p.p_discount_active
),
returns AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        st.s_state AS state,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS returns_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, st.s_state, i.i_category
),
catalog AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        cc.cc_state AS state,
        i.i_category AS category,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state, i.i_category
),
web AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        ws.ws_ship_mode_sk AS ship_mode,
        i.i_category AS category,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, ws.ws_ship_mode_sk, i.i_category
)
SELECT
    s.year,
    s.month_seq,
    s.state,
    s.category,
    s.brand,
    s.pref_cust_flag,
    s.discount_active,
    s.total_net_paid,
    s.total_ext_sales,
    s.total_profit,
    s.sales_count,
    s.uniq_customers,
    COALESCE(r.total_loss, 0) AS total_return_loss,
    COALESCE(r.returns_count, 0) AS total_returns,
    COALESCE(c.total_net_paid, 0) AS catalog_net_paid,
    COALESCE(c.total_ext_sales, 0) AS catalog_ext_sales,
    COALESCE(c.total_profit, 0) AS catalog_profit,
    COALESCE(w.total_net_paid, 0) AS web_net_paid,
    COALESCE(w.total_ext_sales, 0) AS web_ext_sales,
    COALESCE(w.total_profit, 0) AS web_profit
FROM sales s
LEFT JOIN returns r
    ON s.year = r.year
    AND s.month_seq = r.month_seq
    AND s.state = r.state
    AND s.category = r.category
LEFT JOIN catalog c
    ON s.year = c.year
    AND s.month_seq = c.month_seq
    AND s.state = c.state
    AND s.category = c.category
LEFT JOIN web w
    ON s.year = w.year
    AND s.month_seq = w.month_seq
    AND s.category = w.category
ORDER BY s.total_profit DESC
LIMIT 100
