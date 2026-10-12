WITH catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
),
items_only_in_catalog AS (
    SELECT cs.cs_item_sk AS item_only_sk
    FROM catalog_sales cs
    EXCEPT
    SELECT ws.ws_item_sk
    FROM web_sales ws
)
SELECT
    s.s_store_name,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
    SUM(COALESCE(ca.total_catalog_sales, 0)) AS total_catalog_sales,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_category,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_sales cs ON cs.cs_item_sk = ss.ss_item_sk AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_sales_agg ca ON ca.cs_item_sk = ss.ss_item_sk AND ca.cs_sold_date_sk = ss.ss_sold_date_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
LEFT JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
WHERE d.d_year = 2000
  AND s.s_state = 'TX'
  AND i.i_brand = 'Brand#45'
  AND c.c_preferred_cust_flag = 'Y'
  AND i.i_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_ext_discount_amt > 0)
  AND i.i_item_sk IN (SELECT item_only_sk FROM items_only_in_catalog)
GROUP BY s.s_store_name, d.d_year
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_store_sales DESC
