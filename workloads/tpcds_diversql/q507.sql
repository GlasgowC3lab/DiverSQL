WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        t.t_hour,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        ca.ca_state,
        cd.cd_gender,
        r.r_reason_desc,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cc.cc_state AS cc_state,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        p.p_promo_name,
        ws.ws_bill_customer_sk,
        ws.ws_net_paid,
        we.web_name,
        ws_avg.avg_customer_net
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_returns cr
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN (
        SELECT * FROM tpcds.catalog_sales TABLESAMPLE BERNOULLI (10)
    ) cs
      ON cs.cs_order_number = cr.cr_order_number
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT avg(ws2.ws_net_paid) AS avg_customer_net
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
    ) ws_avg
    JOIN tpcds.web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 17
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
      AND cp.cp_catalog_page_sk IN (
          SELECT DISTINCT cr_catalog_page_sk FROM tpcds.catalog_returns
      )
),
agg AS (
    SELECT
        ws_bill_customer_sk,
        SUM(cs_net_paid) AS sum_sales,
        SUM(sr_net_loss) AS sum_returns,
        COUNT(DISTINCT cs_order_number) AS orders,
        MAX(r_reason_desc) AS top_reason,
        MAX(cp_department) AS top_department,
        AVG(avg_customer_net) AS avg_customer_net
    FROM base
    GROUP BY ws_bill_customer_sk
)
SELECT
    ws_bill_customer_sk,
    sum_sales,
    sum_returns,
    orders,
    top_reason,
    top_department,
    avg_customer_net,
    ROW_NUMBER() OVER (ORDER BY sum_sales DESC) AS rn,
    (SELECT MAX(d_year) FROM tpcds.date_dim) AS max_year
FROM agg
WHERE sum_sales > 10000
  AND sum_returns < 5000
  AND orders >= 5
ORDER BY rn
LIMIT 100
