WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      AND hd.hd_vehicle_count >= 2
    GROUP BY ss.ss_sold_date_sk, hd.hd_income_band_sk
),
inventory_agg AS (
    SELECT
        i.inv_date_sk AS date_sk,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
    GROUP BY i.inv_date_sk
),
sales_with_inventory AS (
    SELECT
        s.date_sk,
        s.hd_income_band_sk,
        s.total_net_profit,
        s.avg_discount_amt,
        s.total_quantity,
        COALESCE(i.avg_inventory_qty, 0) AS avg_inventory_qty
    FROM sales_agg s
    LEFT JOIN inventory_agg i ON s.date_sk = i.date_sk
),
aggregated AS (
    SELECT
        cc.cc_division_name,
        d.d_year,
        d.d_month_seq,
        s.hd_income_band_sk,
        SUM(s.total_net_profit) AS month_net_profit,
        AVG(s.avg_discount_amt) AS month_avg_discount,
        SUM(s.total_quantity) AS month_total_quantity,
        AVG(s.avg_inventory_qty) AS month_avg_inventory
    FROM sales_with_inventory s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN call_center cc ON d.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    WHERE cc.cc_manager = 'Bob Belcher'
      AND cc.cc_city = 'Greenwood'
    GROUP BY cc.cc_division_name, d.d_year, d.d_month_seq, s.hd_income_band_sk
    HAVING SUM(s.total_net_profit) > 10000
)
SELECT
    a.cc_division_name,
    a.d_year,
    a.d_month_seq,
    a.hd_income_band_sk,
    a.month_net_profit,
    a.month_avg_discount,
    a.month_total_quantity,
    a.month_avg_inventory,
    RANK() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.month_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.d_year, a.d_month_seq, a.month_net_profit DESC
LIMIT 100
