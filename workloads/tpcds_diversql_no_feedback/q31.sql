WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_wholesale_cost,
        cs.cs_quantity,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        i.i_brand,
        i.i_category,
        w.w_warehouse_name,
        w.w_gmt_offset,
        td.t_hour,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        COALESCE(cr.cr_return_amount, 0)      AS catalog_return_amount,
        COALESCE(sr.sr_return_amt, 0)        AS store_return_amount,
        COALESCE(wr.wr_return_amt, 0)        AS web_return_amount
    FROM catalog_sales cs
    JOIN time_dim td               ON cs.cs_sold_time_sk   = td.t_time_sk
    JOIN item i                    ON cs.cs_item_sk        = i.i_item_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr   ON cr.cr_item_sk = cs.cs_item_sk
                                   AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr    ON sr.sr_item_sk = i.i_item_sk
                                   AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s              ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr      ON wr.wr_item_sk = i.i_item_sk
                                   AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE cs.cs_wholesale_cost > 30.00
      AND cs.cs_quantity >= 2
      AND i.i_brand = 'BrandX'
      AND td.t_hour BETWEEN 9 AND 17
      AND w.w_gmt_offset = -5.00
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_upper_bound <= 50000
), aggregated AS (
    SELECT
        cs_sold_date_sk,
        i_brand,
        i_category,
        w_warehouse_name,
        t_hour,
        hd_income_band_sk,
        SUM(cs_net_paid)               AS total_net_paid,
        SUM(cs_ext_sales_price)        AS total_sales_price,
        SUM(catalog_return_amount)     AS total_catalog_return_amount,
        SUM(store_return_amount)       AS total_store_return_amount,
        SUM(web_return_amount)         AS total_web_return_amount,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM base
    GROUP BY
        cs_sold_date_sk,
        i_brand,
        i_category,
        w_warehouse_name,
        t_hour,
        hd_income_band_sk
)
SELECT
    cs_sold_date_sk,
    i_brand,
    i_category,
    w_warehouse_name,
    t_hour,
    hd_income_band_sk,
    total_net_paid,
    total_sales_price,
    total_catalog_return_amount,
    total_store_return_amount,
    total_web_return_amount,
    distinct_orders,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM aggregated
ORDER BY rn
LIMIT 100
