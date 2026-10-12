WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS sales_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY CUBE (s.s_store_name, d.d_year, p.p_promo_name)
),
returns_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        p.p_promo_name,
        SUM(sr.sr_return_amt) AS return_amount
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY CUBE (s.s_store_name, d.d_year, p.p_promo_name)
)
SELECT
    s_store_name,
    d_year,
    p_promo_name,
    sales_amount
FROM sales_agg
EXCEPT
SELECT
    s_store_name,
    d_year,
    p_promo_name,
    return_amount
FROM returns_agg
