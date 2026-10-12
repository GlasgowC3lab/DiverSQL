WITH intersect_keys AS (
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_state = 'CA'
    INTERSECT
    SELECT cs_warehouse_sk
    FROM catalog_sales
    WHERE cs_quantity > 10
),

sales_detail AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        ca.ca_state,
        cc.cc_state,
        w.w_city,
        p.p_discount_active,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        t.t_hour,
        CASE WHEN hd.hd_vehicle_count > 2 THEN 'ManyVehicles' ELSE 'FewVehicles' END AS vehicle_category,
        cp.cp_department
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cc.cc_state = 'CA'
      AND w.w_city = 'Los Angeles'
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound <= 100000
      AND hd.hd_vehicle_count >= 2
      AND cs.cs_call_center_sk IN (SELECT cc_call_center_sk FROM call_center WHERE cc_country = 'USA')
      AND cs.cs_warehouse_sk IN (SELECT w_warehouse_sk FROM intersect_keys)
),

agg AS (
    SELECT
        sd.cs_promo_sk,
        sd.cs_call_center_sk,
        SUM(sd.cs_net_profit) AS total_profit,
        COUNT(DISTINCT sd.cs_bill_customer_sk) AS unique_customers,
        SUM(DISTINCT sd.cs_ext_sales_price) AS sum_distinct_sales_price,
        COUNT(DISTINCT cr.cr_return_quantity) AS distinct_return_qty,
        SUM(DISTINCT wr.wr_return_amt) AS sum_distinct_web_return
    FROM sales_detail sd
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = sd.cs_order_number
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = sd.cs_sold_time_sk
    GROUP BY sd.cs_promo_sk, sd.cs_call_center_sk
)
SELECT
    p.p_promo_id,
    cc.cc_name,
    a.total_profit,
    a.unique_customers,
    a.sum_distinct_sales_price,
    a.distinct_return_qty,
    a.sum_distinct_web_return,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
JOIN promotion p ON a.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON a.cs_call_center_sk = cc.cc_call_center_sk
WHERE a.total_profit > 0
ORDER BY a.total_profit DESC
LIMIT 100
