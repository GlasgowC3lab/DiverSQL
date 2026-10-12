WITH sales_site AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_tax AS ext_tax,
        ws.ws_web_site_sk,
        wsit.web_site_sk,
        wsit.web_company_name,
        wsit.web_name,
        wsit.web_city,
        wsit.web_state,
        REGEXP_EXTRACT(wsit.web_company_name, '(\\w{3})') AS company_prefix,
        CASE WHEN wsit.web_name IS NOT NULL THEN CONCAT(wsit.web_city, ', ', wsit.web_state) ELSE NULL END AS location
    FROM web_sales ws
    FULL OUTER JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE (wsit.web_name LIKE '%Shop%' OR wsit.web_name IS NULL)
      AND (ws.ws_ext_tax > 20 OR ws.ws_ext_tax IS NULL)
)
SELECT
    COALESCE(company_prefix, 'UNKNOWN') AS company_prefix,
    COUNT(DISTINCT order_number) AS orders_cnt,
    SUM(net_paid) AS total_net_paid,
    AVG(ext_tax) AS avg_ext_tax,
    MAX(location) FILTER (WHERE location IS NOT NULL) AS sample_location
FROM sales_site
GROUP BY COALESCE(company_prefix, 'UNKNOWN')
ORDER BY total_net_paid DESC
LIMIT 100
