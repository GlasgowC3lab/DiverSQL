WITH base AS (
    SELECT
        ws.ws_item_sk,
        i.i_item_id,
        i.i_class,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ca.ca_state,
        cd.cd_gender,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        sr.sr_return_amt_inc_tax AS store_return_amount,
        cr.cr_return_amt_inc_tax AS catalog_return_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
      AND i.i_class IN ('toddlers', 'furniture')
      AND ws.ws_quantity > 1
      AND ws.ws_net_profit > 0
      AND ca.ca_state = 'NY'
      AND cd.cd_gender = 'M'
      AND wsite.web_state = 'CA'
),
agg AS (
    SELECT
        i_item_id,
        i_class,
        ca_state,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(COALESCE(store_return_amount, 0)) AS total_store_returns,
        SUM(COALESCE(catalog_return_amount, 0)) AS total_catalog_returns,
        SUM(ws_net_profit) AS total_profit
    FROM base
    GROUP BY i_item_id, i_class, ca_state
    HAVING SUM(ws_ext_sales_price) > 1000
)
SELECT
    a.i_class,
    COUNT(*) AS num_items,
    SUM(a.total_sales) AS class_sales,
    AVG(a.total_sales) AS avg_item_sales,
    (SELECT AVG(total_sales) FROM agg) AS overall_avg_sales,
    SUM(a.total_profit) AS class_profit,
    (SUM(a.total_sales) - SUM(a.total_store_returns) - SUM(a.total_catalog_returns)) AS net_sales_after_returns
FROM agg a
WHERE a.total_store_returns < a.total_sales * 0.2
  AND a.total_catalog_returns < a.total_sales * 0.1
GROUP BY a.i_class
ORDER BY class_sales DESC
LIMIT 100
