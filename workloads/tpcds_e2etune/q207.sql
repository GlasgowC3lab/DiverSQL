WITH sales_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_sales_customers,
        COUNT(DISTINCT cs.cs_ship_customer_sk) AS distinct_ship_customers
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
      AND cs.cs_net_paid_inc_ship_tax > 0
    GROUP BY cs.cs_ship_mode_sk, cs.cs_sold_date_sk
),
returns_agg AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_returned_date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_return_customers,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND cr.cr_net_loss > 0
    GROUP BY cr.cr_ship_mode_sk, cr.cr_returned_date_sk
),
webpage_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
    FROM catalog_sales cs
    JOIN web_page wp ON wp.wp_customer_sk = cs.cs_bill_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cs.cs_ship_mode_sk, cs.cs_sold_date_sk
)
SELECT
    sm.sm_ship_mode_id,
    CAST(sales.cs_sold_date_sk AS VARCHAR) AS sold_date_sk,
    sales.total_sales,
    sales.total_profit,
    returns.total_return_amount,
    returns.total_net_loss,
    sales.distinct_sales_customers,
    returns.distinct_return_customers,
    wp.distinct_web_pages,
    RANK() OVER (ORDER BY sales.total_profit DESC) AS profit_rank
FROM sales_agg sales
LEFT JOIN returns_agg returns
    ON sales.cs_ship_mode_sk = returns.cr_ship_mode_sk
   AND sales.cs_sold_date_sk = returns.cr_returned_date_sk
LEFT JOIN webpage_agg wp
    ON sales.cs_ship_mode_sk = wp.cs_ship_mode_sk
   AND sales.cs_sold_date_sk = wp.cs_sold_date_sk
JOIN ship_mode sm
    ON sales.cs_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY profit_rank
LIMIT 100
