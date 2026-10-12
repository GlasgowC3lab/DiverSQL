WITH catalog_agg AS (
    SELECT
        cp.cp_department AS group_key,
        p.p_channel_radio AS channel_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_type = 'monthly'
      AND p.p_channel_radio = 'N'
    GROUP BY GROUPING SETS (
        (cp.cp_department, p.p_channel_radio),
        (cp.cp_department),
        (p.p_channel_radio),
        ()
    )
),
web_agg AS (
    SELECT
        wsite.web_name AS group_key,
        p.p_channel_tv AS channel_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE wsite.web_state = 'CA'
      AND p.p_channel_tv = 'Y'
    GROUP BY GROUPING SETS (
        (wsite.web_name, p.p_channel_tv),
        (wsite.web_name),
        (p.p_channel_tv),
        ()
    )
)
SELECT
    group_key,
    channel_type,
    total_sales,
    total_profit
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY total_sales DESC
