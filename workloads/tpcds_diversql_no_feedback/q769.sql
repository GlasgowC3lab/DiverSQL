WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
),
joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        cp.cp_department,
        w.w_warehouse_name,
        base.cs_ext_sales_price,
        base.cs_net_profit,
        base.cs_quantity,
        d.d_date_sk,
        t.t_hour,
        we.web_country,
        cp.cp_type,
        c.c_customer_sk,
        d.d_date_sk AS join_date_sk,
        base.cs_bill_customer_sk AS join_cust_sk
    FROM base
    JOIN date_dim d ON base.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON base.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON base.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON base.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON base.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON base.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON base.cs_warehouse_sk = w.w_warehouse_sk
    -- join additional tables through the shared date and customer keys
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '>10000'
      AND we.web_country = 'United States'
      AND cp.cp_type = 'Catalog'
      AND EXISTS (
          SELECT 1 FROM store_sales ss2
          WHERE ss2.ss_customer_sk = c.c_customer_sk
            AND ss2.ss_sold_date_sk = d.d_date_sk
            AND ss2.ss_quantity > 5
      )
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        c_customer_id,
        cd_gender,
        hd_buy_potential,
        cp_department,
        w_warehouse_name,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_ext_sales_price) AS avg_sales,
        COUNT(DISTINCT join_cust_sk) AS distinct_customers,
        MAX(cs_net_profit) AS max_profit
    FROM joined
    GROUP BY
        d_year,
        d_month_seq,
        c_customer_id,
        cd_gender,
        hd_buy_potential,
        cp_department,
        w_warehouse_name
)
SELECT
    d_year,
    d_month_seq,
    c_customer_id,
    cd_gender,
    hd_buy_potential,
    cp_department,
    w_warehouse_name,
    total_sales,
    avg_sales,
    distinct_customers,
    max_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
