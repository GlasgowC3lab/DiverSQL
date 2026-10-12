WITH base AS (
    SELECT
        cc.cc_city,
        sm.sm_carrier,
        i.i_color,
        d.d_year,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        p.p_promo_name,
        CASE WHEN sm.sm_carrier = 'USPS' THEN 'Domestic' ELSE 'International' END AS carrier_type
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN "store" s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cc.cc_city = 'Salem'
      AND sm.sm_carrier = 'USPS'
      AND i.i_color = 'Red'
      AND d.d_year = 2001
      AND cs.cs_quantity > (
          SELECT MAX(cs2.cs_quantity)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = d.d_date_sk
      )
)
SELECT
    carrier_type,
    cc_city,
    i_color,
    d_year,
    COUNT(*) AS order_cnt,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_quantity) AS avg_quantity,
    MIN(cs_quantity) AS min_quantity,
    MAX(cs_quantity) AS max_quantity
FROM (
    SELECT
        cc_city,
        sm_carrier,
        i_color,
        d_year,
        cs_quantity,
        cs_ext_sales_price,
        p_promo_name,
        carrier_type
    FROM base
    WHERE p_promo_name = 'Summer Sale'
    UNION
    SELECT
        cc_city,
        sm_carrier,
        i_color,
        d_year,
        cs_quantity,
        cs_ext_sales_price,
        p_promo_name,
        carrier_type
    FROM base
    WHERE p_promo_name = 'Winter Sale'
) u
GROUP BY carrier_type, cc_city, i_color, d_year
ORDER BY total_sales DESC
LIMIT 100
