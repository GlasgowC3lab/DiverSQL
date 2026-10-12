WITH sales_agg AS (
    SELECT
        d_sold.d_year AS year,
        i.i_brand AS brand,
        cc.cc_state AS state,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM
        catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        d_sold.d_year = 2002
        AND i.i_brand = 'Brand#12'
        AND cc.cc_state = 'CA'
        AND cp.cp_catalog_number IN (2, 7, 12)
        AND ib.ib_upper_bound > 50000
        AND t.t_hour BETWEEN 9 AND 17
        AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = cs.cs_item_sk
              AND ws2.ws_sold_date_sk = cs.cs_sold_date_sk
        )
    GROUP BY
        d_sold.d_year,
        i.i_brand,
        cc.cc_state
)
SELECT
    year,
    AVG(total_sales) AS avg_total_sales
FROM
    sales_agg
GROUP BY
    year
HAVING
    AVG(total_sales) > 1000
ORDER BY
    avg_total_sales DESC
LIMIT 100
