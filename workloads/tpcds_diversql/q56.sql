WITH cs_agg AS (
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_bill_addr_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_order_number,
        SUM(cs_net_paid) AS order_net_paid
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451545 AND 2451910   -- filter on surrogate date key range
      AND cs_quantity > 0                           -- only positive quantity
      AND cs_net_paid > 0                           -- positive revenue
      AND cs_wholesale_cost IS NOT NULL
      AND cs_list_price IS NOT NULL
      AND cs_sales_price IS NOT NULL
    GROUP BY
        cs_sold_date_sk,
        cs_item_sk,
        cs_bill_addr_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_order_number
)
SELECT
    d.d_year,
    i.i_category,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    COUNT(DISTINCT cs_agg.cs_order_number)               AS distinct_order_cnt,
    SUM(cs_agg.order_net_paid)                           AS total_net_paid,
    COUNT(DISTINCT r_cat.r_reason_sk)                    AS distinct_catalog_return_reasons,
    COUNT(DISTINCT r_web.r_reason_sk)                    AS distinct_web_return_reasons,
    COUNT(DISTINCT ss.ss_customer_sk)                    AS distinct_store_customers,
    COUNT(DISTINCT ws.ws_bill_customer_sk)              AS distinct_web_customers
FROM cs_agg
JOIN date_dim d        ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN item i            ON cs_agg.cs_item_sk = i.i_item_sk
JOIN promotion p       ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN call_center cc    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm      ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w       ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib    ON hd.hd_income_band_sk = ib.ib_income_band_sk
-- Catalog returns and their reason
LEFT JOIN catalog_returns cr   ON cr.cr_order_number = cs_agg.cs_order_number
LEFT JOIN reason r_cat          ON cr.cr_reason_sk = r_cat.r_reason_sk
-- Store sales (joined through the same date and item)
JOIN store_sales ss            ON ss.ss_sold_date_sk = d.d_date_sk
                               AND ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics ss_cd ON ss.ss_cdemo_sk = ss_cd.cd_demo_sk
JOIN household_demographics ss_hd ON ss.ss_hdemo_sk = ss_hd.hd_demo_sk
JOIN customer_address ss_ca   ON ss.ss_addr_sk = ss_ca.ca_address_sk
JOIN promotion ss_p           ON ss.ss_promo_sk = ss_p.p_promo_sk
-- Web sales and related returns
JOIN web_sales ws              ON ws.ws_sold_date_sk = d.d_date_sk
                               AND ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr            ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_web         ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN customer_demographics ws_cd ON ws.ws_bill_cdemo_sk = ws_cd.cd_demo_sk
JOIN household_demographics ws_hd ON ws.ws_bill_hdemo_sk = ws_hd.hd_demo_sk
JOIN customer_address ws_ca    ON ws.ws_bill_addr_sk = ws_ca.ca_address_sk
JOIN promotion ws_p            ON ws.ws_promo_sk = ws_p.p_promo_sk
WHERE
    i.i_category = 'Sports'                -- filter on product category
    AND cc.cc_state = 'CA'                  -- call‑center located in California
    AND sm.sm_carrier = 'UPS'               -- specific ship‑mode carrier
    AND w.w_state = 'CA'                    -- warehouse in California
    AND ca.ca_country = 'United States'    -- address country filter
    AND d.d_year = 2001                     -- year of interest
    AND cd.cd_marital_status = 'M'         -- married customers
    AND hd.hd_vehicle_count >= 2           -- households with at least two vehicles
GROUP BY ROLLUP (d.d_year, i.i_category, cc.cc_name, sm.sm_type, w.w_warehouse_name)
ORDER BY
    d.d_year ASC,
    i.i_category ASC,
    cc.cc_name ASC,
    sm.sm_type ASC,
    w.w_warehouse_name ASC
