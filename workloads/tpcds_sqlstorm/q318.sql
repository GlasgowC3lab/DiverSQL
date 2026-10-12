WITH unified_sales AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state AS region,
        coalesce(p.p_promo_name, 'No Promo') AS promo_name,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        cc.cc_state AS region,
        coalesce(p.p_promo_name, 'No Promo') AS promo_name,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        ws_site.web_state AS region,
        coalesce(p.p_promo_name, 'No Promo') AS promo_name,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
aggregated AS (
    SELECT
        d_year,
        i_category,
        region,
        promo_name,
        count(*) AS sales_cnt,
        sum(net_paid) AS total_net_paid,
        sum(net_profit) AS total_net_profit,
        avg(net_profit) AS avg_profit
    FROM unified_sales
    GROUP BY d_year, i_category, region, promo_name
)
SELECT
    d_year,
    i_category,
    region,
    promo_name,
    sales_cnt,
    total_net_paid,
    total_net_profit,
    avg_profit,
    rank() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, profit_rank
