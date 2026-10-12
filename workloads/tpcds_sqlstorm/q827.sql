WITH call_center_sales AS (
    SELECT 
        cc.cc_call_center_sk,
        cc.cc_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        MAX(cs.cs_sold_date_sk) AS latest_sale_sk
    FROM call_center cc
    LEFT JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY cc.cc_call_center_sk, cc.cc_name, d.d_year
),
store_sales_agg AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets,
        MAX(ss.ss_sold_date_sk) AS latest_sale_sk
    FROM store s
    LEFT JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
),
promo_effect AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COALESCE(SUM(cs.cs_ext_sales_price) FILTER (WHERE cs.cs_promo_sk = p.p_promo_sk), 0) AS promo_sales,
        COALESCE(SUM(ss.ss_ext_sales_price) FILTER (WHERE ss.ss_promo_sk = p.p_promo_sk), 0) AS store_promo_sales
    FROM promotion p
    LEFT JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
),
sales_rankings AS (
    SELECT 
        source,
        identifier,
        year,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY source, year ORDER BY total_sales DESC) AS sales_rank,
        PERCENT_RANK() OVER (PARTITION BY source, year ORDER BY total_sales) AS pct_rank
    FROM (
        SELECT 
            'call_center' AS source,
            CAST(cc.cc_call_center_sk AS VARCHAR) || ':' || cc.cc_name AS identifier,
            cc.d_year AS year,
            cc.total_sales
        FROM call_center_sales cc
        UNION ALL
        SELECT 
            'store' AS source,
            CAST(ss.s_store_sk AS VARCHAR) || ':' || ss.s_store_name AS identifier,
            ss.d_year AS year,
            ss.total_sales
        FROM store_sales_agg ss
    ) u
),
daily_avg AS (
    SELECT 
        sr.identifier,
        sr.year,
        sr.sales_rank,
        sr.total_sales,
        (SELECT AVG(t2.total_sales)
         FROM sales_rankings t2
         WHERE t2.source = sr.source AND t2.year = sr.year) AS avg_total_sales_for_source_year,
        CASE 
            WHEN sr.total_sales > 0 
                 AND (SELECT AVG(t2.total_sales)
                      FROM sales_rankings t2
                      WHERE t2.source = sr.source AND t2.year = sr.year) IS NOT NULL
                 AND sr.total_sales > 2 * (SELECT AVG(t2.total_sales)
                                            FROM sales_rankings t2
                                            WHERE t2.source = sr.source AND t2.year = sr.year)
                THEN 'HIGH'
            WHEN sr.total_sales > 0 
                 AND sr.total_sales > (SELECT AVG(t2.total_sales)
                                      FROM sales_rankings t2
                                      WHERE t2.source = sr.source AND t2.year = sr.year)
                THEN 'MEDIUM'
            ELSE 'LOW'
        END AS performance_bucket,
        CONCAT('Rank ', CAST(sr.sales_rank AS VARCHAR), ' in ', CAST(sr.year AS VARCHAR)) AS rank_desc,
        (SELECT COUNT(*) FROM promotion p WHERE p.p_promo_id IS NOT NULL) AS total_promos
    FROM sales_rankings sr
    WHERE sr.sales_rank <= 10
)
SELECT 
    da.identifier,
    da.year,
    da.sales_rank,
    da.total_sales,
    COALESCE(da.avg_total_sales_for_source_year, 0) AS avg_total_sales,
    da.performance_bucket,
    da.rank_desc,
    da.total_promos
FROM (
    SELECT 
        d.identifier,
        d.year,
        d.sales_rank,
        d.total_sales,
        d.avg_total_sales_for_source_year,
        d.performance_bucket,
        d.rank_desc,
        d.total_promos,
        ROW_NUMBER() OVER (PARTITION BY d.year ORDER BY d.sales_rank) AS rn
    FROM daily_avg d
    WHERE NOT (d.identifier LIKE '%NULL%' OR d.identifier IS NULL)
) da
WHERE da.rn <= 5
UNION ALL
SELECT 
    CONCAT('Promo:', pe.p_promo_name) AS identifier,
    0 AS year,
    0 AS sales_rank,
    (pe.promo_sales + pe.store_promo_sales) AS total_sales,
    (pe.promo_sales + pe.store_promo_sales) / NULLIF((SELECT COUNT(*) FROM date_dim WHERE d_year BETWEEN 2000 AND 2002), 0) AS avg_total_sales,
    CASE 
        WHEN (pe.promo_sales + pe.store_promo_sales) > 1000000 THEN 'HIGH'
        ELSE 'LOW'
    END AS performance_bucket,
    CONCAT('Promo ', pe.p_promo_name, ' Effect') AS rank_desc,
    NULL AS total_promos
FROM promo_effect pe
WHERE (pe.promo_sales + pe.store_promo_sales) > 0
ORDER BY year DESC, total_sales DESC NULLS LAST
