WITH sales AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_moy AS sale_month,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY ss.ss_store_sk, d.d_year, d.d_moy, i.i_category
), returns AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_year,
        d.d_moy AS sale_month,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY sr.sr_store_sk, d.d_year, d.d_moy, i.i_category
)
SELECT
    s.s_store_name,
    s.s_state,
    sales.d_year,
    sales.sale_month,
    sales.i_category,
    sales.total_sales,
    COALESCE(returns.total_return_amt, 0) AS total_return_amt,
    sales.total_profit - COALESCE(returns.total_return_amt, 0) AS net_profit_after_returns,
    sales.total_quantity,
    COALESCE(returns.total_return_qty, 0) AS total_return_qty
FROM sales
LEFT JOIN returns
    ON sales.store_sk = returns.store_sk
    AND sales.d_year = returns.d_year
    AND sales.sale_month = returns.sale_month
    AND sales.i_category = returns.i_category
JOIN store s ON sales.store_sk = s.s_store_sk
ORDER BY sales.total_sales DESC
LIMIT 100
