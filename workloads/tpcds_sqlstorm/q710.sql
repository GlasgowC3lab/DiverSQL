WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        p.p_promo_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
        AND ss.ss_item_sk = p.p_item_sk
    WHERE d.d_year = 2001
    GROUP BY
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        p.p_promo_name
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        p.p_promo_name,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON sr.sr_item_sk = p.p_item_sk
        AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE dr.d_year = 2001
    GROUP BY
        sr.sr_store_sk,
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        p.p_promo_name
),
combined AS (
    SELECT
        s.store_sk,
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.i_class,
        s.i_brand,
        COALESCE(s.p_promo_name, r.p_promo_name) AS promo_name,
        s.total_quantity,
        s.total_sales_amount,
        s.total_net_profit,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.store_sk = r.store_sk
        AND s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.i_category = r.i_category
        AND s.i_class = r.i_class
        AND s.i_brand = r.i_brand
        AND COALESCE(s.p_promo_name, '') = COALESCE(r.p_promo_name, '')
),
ranked AS (
    SELECT
        st.s_store_name AS store_name,
        c.d_year,
        c.d_month_seq,
        c.i_category,
        c.i_class,
        c.i_brand,
        c.promo_name,
        c.total_quantity,
        c.total_sales_amount,
        c.total_net_profit,
        c.total_return_quantity,
        c.total_return_amount,
        c.total_return_loss,
        c.net_profit_after_returns,
        ROW_NUMBER() OVER (PARTITION BY c.store_sk, c.d_year, c.d_month_seq ORDER BY c.net_profit_after_returns DESC) AS rank
    FROM combined c
    JOIN store st ON c.store_sk = st.s_store_sk
)
SELECT
    store_name,
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    promo_name,
    total_quantity,
    total_sales_amount,
    total_net_profit,
    total_return_quantity,
    total_return_amount,
    total_return_loss,
    net_profit_after_returns,
    rank
FROM ranked
WHERE rank <= 10
ORDER BY store_name, d_year, d_month_seq, rank
