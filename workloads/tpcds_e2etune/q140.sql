WITH sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_sales_price > 2000
      AND cs.cs_ext_discount_amt BETWEEN 500 AND 1500
      AND cd.cd_credit_rating = 'Excellent'
    GROUP BY cd.cd_gender, cd.cd_education_status, hd.hd_vehicle_count
),
returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        wp.wp_type,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
    FROM web_returns wr
    JOIN customer_demographics cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt > 500
    GROUP BY cd.cd_gender, cd.cd_education_status, hd.hd_vehicle_count, wp.wp_type
)
SELECT
    s.cd_gender,
    s.cd_education_status,
    s.hd_vehicle_count,
    r.wp_type,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.avg_discount_amount,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    s.distinct_orders,
    COALESCE(r.distinct_returns, 0) AS distinct_returns
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cd_gender = r.cd_gender
 AND s.cd_education_status = r.cd_education_status
 AND s.hd_vehicle_count = r.hd_vehicle_count
WHERE s.total_sales_profit > 5000
ORDER BY net_profit_after_returns DESC
LIMIT 20
