WITH sales_agg AS (
    SELECT 
        s.s_store_id,
        d.d_year,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns,
        AVG(CASE WHEN ss.ss_ext_sales_price <> 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_sales_price END) AS avg_discount_rate
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY s.s_store_id, d.d_year, i.i_category, p.p_promo_name
),
sales_with_net AS (
    SELECT 
        s_store_id,
        d_year,
        i_category,
        p_promo_name,
        total_sales,
        total_discount,
        net_profit,
        total_returns,
        (total_sales - total_returns) AS net_sales,
        avg_discount_rate
    FROM sales_agg
),
sales_with_growth AS (
    SELECT 
        s_store_id,
        d_year,
        i_category,
        p_promo_name,
        total_sales,
        total_discount,
        net_profit,
        total_returns,
        net_sales,
        avg_discount_rate,
        LAG(net_sales) OVER (PARTITION BY s_store_id, i_category ORDER BY d_year) AS prev_year_sales
    FROM sales_with_net
),
ranked_sales AS (
    SELECT 
        s_store_id,
        d_year,
        i_category,
        COALESCE(p_promo_name, 'No Promo') AS promo_name,
        total_sales,
        total_discount,
        net_profit,
        total_returns,
        net_sales,
        avg_discount_rate,
        prev_year_sales,
        CASE 
            WHEN prev_year_sales IS NULL OR prev_year_sales = 0 THEN NULL
            ELSE (net_sales - prev_year_sales) / prev_year_sales
        END AS yoy_growth,
        SUM(net_sales) OVER (PARTITION BY s_store_id, d_year) AS store_year_total_sales,
        net_sales / NULLIF(SUM(net_sales) OVER (PARTITION BY s_store_id, d_year), 0) AS category_sales_share,
        ROW_NUMBER() OVER (PARTITION BY s_store_id, d_year ORDER BY net_profit DESC) AS profit_rank
    FROM sales_with_growth
)
SELECT 
    s_store_id,
    d_year,
    i_category,
    promo_name,
    total_sales,
    total_discount,
    net_profit,
    total_returns,
    net_sales,
    avg_discount_rate,
    prev_year_sales,
    yoy_growth,
    store_year_total_sales,
    category_sales_share,
    profit_rank
FROM ranked_sales
WHERE profit_rank <= 5
ORDER BY s_store_id, d_year, profit_rank
