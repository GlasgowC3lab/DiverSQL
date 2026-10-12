WITH sales_agg AS (
    SELECT
        d.d_year,
        cc.cc_name,
        w.w_city,
        i.i_brand,
        i.i_category,
        i.i_color,
        ca.ca_location_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        wp.wp_url,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND w.w_city = 'Seattle'
      AND i.i_color = 'Blue'
      AND ca.ca_location_type = 'condo'
      AND cs.cs_item_sk IN (
          SELECT i2.i_item_sk
          FROM item i2
          WHERE i2.i_brand = 'Brand#12'
      )
      AND cs.cs_ext_sales_price > (
          SELECT MAX(cs2.cs_ext_sales_price)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 2450000
      )
    GROUP BY
        d.d_year,
        cc.cc_name,
        w.w_city,
        i.i_brand,
        i.i_category,
        i.i_color,
        ca.ca_location_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        wp.wp_url
)
SELECT
    d_year,
    cc_name,
    w_city,
    i_brand,
    i_category,
    i_color,
    ca_location_type,
    cd_gender,
    hd_buy_potential,
    ib_upper_bound,
    wp_url,
    total_sales,
    total_profit,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS brand_sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
