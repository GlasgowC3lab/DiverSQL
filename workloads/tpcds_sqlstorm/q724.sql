WITH date_info AS (
    SELECT d_date_sk,
           date_format(d_date, '%Y-%m') AS year_month,
           d_year,
           d_month_seq,
           d_quarter_name,
           d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '1998-01-01' AND DATE '1999-12-31'
),
store_sales_agg AS (
    SELECT
        di.year_month,
        s.s_store_id,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS uniq_customers,
        COALESCE(p.p_discount_active, 'N') AS promo_active_flag,
        SUM(COALESCE(p.p_cost, 0)) AS promo_total_cost
    FROM store_sales ss
    JOIN date_info di ON ss.ss_sold_date_sk = di.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND di.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY di.year_month,
             s.s_store_id,
             CONCAT(s.s_store_name, ' - ', s.s_city),
             COALESCE(p.p_discount_active, 'N')
),
catalog_sales_agg AS (
    SELECT
        di.year_month,
        NULL AS s_store_id,
        NULL AS store_full_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS uniq_customers,
        COALESCE(p.p_discount_active, 'N') AS promo_active_flag,
        SUM(COALESCE(p.p_cost, 0)) AS promo_total_cost
    FROM catalog_sales cs
    JOIN date_info di ON cs.cs_sold_date_sk = di.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk AND di.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY di.year_month,
             COALESCE(p.p_discount_active, 'N')
),
combined AS (
    SELECT
        year_month,
        'store' AS sales_channel,
        s_store_id AS channel_id,
        store_full_name,
        total_net_paid,
        total_net_profit,
        total_quantity,
        uniq_customers,
        promo_active_flag,
        promo_total_cost
    FROM store_sales_agg
    UNION ALL
    SELECT
        year_month,
        'catalog' AS sales_channel,
        NULL AS channel_id,
        NULL AS store_full_name,
        total_net_paid,
        total_net_profit,
        total_quantity,
        uniq_customers,
        promo_active_flag,
        promo_total_cost
    FROM catalog_sales_agg
),
final AS (
    SELECT
        c.year_month,
        c.sales_channel,
        c.channel_id,
        c.store_full_name,
        c.total_net_paid,
        c.total_net_profit,
        c.total_quantity,
        c.uniq_customers,
        c.promo_active_flag,
        c.promo_total_cost,
        AVG(c.total_net_profit) OVER (PARTITION BY c.sales_channel ORDER BY c.year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS mov_avg_3m_net_profit,
        (SELECT COALESCE(SUM(pc.total_net_profit), 0)
         FROM combined pc
         WHERE pc.sales_channel = c.sales_channel
           AND pc.year_month = date_format(date_add('year', -1, date_parse(c.year_month || '-01', '%Y-%m-%d')), '%Y-%m')
        ) AS prior_year_net_profit,
        CASE WHEN c.sales_channel = 'store' THEN
            ROW_NUMBER() OVER (PARTITION BY c.year_month ORDER BY c.total_net_profit DESC)
        END AS store_rank
    FROM combined c
)
SELECT
    year_month,
    sales_channel,
    CASE WHEN channel_id IS NULL THEN '-' ELSE CAST(channel_id AS VARCHAR) END AS channel_id,
    COALESCE(store_full_name, '-') AS store_full_name,
    total_net_paid,
    total_net_profit,
    total_quantity,
    uniq_customers,
    promo_active_flag,
    promo_total_cost,
    mov_avg_3m_net_profit,
    prior_year_net_profit,
    store_rank
FROM final
ORDER BY year_month DESC, sales_channel, total_net_profit DESC
LIMIT 100
