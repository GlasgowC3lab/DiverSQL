WITH sales_agg AS (
    SELECT
        cc.cc_name,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    WHERE p.p_channel_tv = 'N'
      AND ws.ws_ship_addr_sk IN (3230112, 1818264)
      AND cc.cc_state = 'CA'
      AND hd_bill.hd_income_band_sk > 5
    GROUP BY
        cc.cc_name,
        p.p_promo_name
)
SELECT
    cc_name,
    p_promo_name,
    catalog_sales_total,
    web_sales_total,
    (catalog_sales_total + web_sales_total) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY (catalog_sales_total + web_sales_total) DESC) AS rn
FROM sales_agg
WHERE (catalog_sales_total + web_sales_total) > 10000
ORDER BY total_sales DESC
LIMIT 100
