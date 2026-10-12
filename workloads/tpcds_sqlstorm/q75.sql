WITH sales AS (
    SELECT 
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        i.i_brand AS brand,
        i.i_category AS category,
        sum(ss.ss_ext_sales_price) AS sales_amount,
        sum(ss.ss_ext_discount_amt) AS discount_amount,
        sum(ss.ss_net_profit) AS profit_amount,
        count(*) AS num_sales,
        avg(ss.ss_coupon_amt) AS avg_coupon
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY ss.ss_sold_date_sk, d.d_year, d.d_month_seq,
             ss.ss_store_sk, ss.ss_customer_sk,
             i.i_brand, i.i_category
),
returns AS (
    SELECT 
        sr.sr_returned_date_sk,
        d.d_year,
        d.d_month_seq,
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sum(sr.sr_return_amt) AS return_amount,
        sum(sr.sr_net_loss) AS net_loss,
        count(*) AS num_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY sr.sr_returned_date_sk, d.d_year, d.d_month_seq,
             sr.sr_store_sk, sr.sr_customer_sk
)
SELECT 
    s.s_state,
    s.s_store_name,
    c.c_customer_id,
    sales.d_year,
    sales.d_month_seq,
    sales.brand,
    sales.category,
    sales.sales_amount,
    coalesce(returns.return_amount, 0) AS returns_amount,
    (sales.profit_amount - coalesce(returns.net_loss, 0)) AS net_profit,
    sales.num_sales,
    coalesce(returns.num_returns, 0) AS num_returns
FROM sales
LEFT JOIN returns
   ON sales.ss_store_sk = returns.sr_store_sk
   AND sales.ss_customer_sk = returns.sr_customer_sk
   AND sales.d_year = returns.d_year
   AND sales.d_month_seq = returns.d_month_seq
JOIN store s ON sales.ss_store_sk = s.s_store_sk
JOIN customer c ON sales.ss_customer_sk = c.c_customer_sk
ORDER BY s.s_state, sales.d_year, sales.d_month_seq, sales.sales_amount DESC
LIMIT 100
