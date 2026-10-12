WITH sales AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_quantity,
    ss.ss_net_paid_inc_tax,
    ss.ss_net_profit,
    ss.ss_ext_discount_amt,
    ss.ss_ext_sales_price
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
),
returns AS (
  SELECT
    sr.sr_item_sk,
    sr.sr_ticket_number,
    sr.sr_refunded_cash,
    sr.sr_return_quantity,
    sr.sr_net_loss
  FROM store_returns sr
  WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
),
joined AS (
  SELECT
    i.i_category,
    cd.cd_gender,
    s.ss_net_paid_inc_tax AS sales_amount,
    s.ss_net_profit AS profit_amount,
    COALESCE(r.sr_refunded_cash, 0) AS refund_amount,
    s.ss_ext_discount_amt AS discount_amount,
    s.ss_quantity AS quantity_sold,
    COALESCE(r.sr_return_quantity, 0) AS quantity_returned
  FROM sales s
  LEFT JOIN returns r
    ON s.ss_item_sk = r.sr_item_sk
   AND s.ss_ticket_number = r.sr_ticket_number
  JOIN item i
    ON s.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON s.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE c.c_birth_country = 'MEXICO'
    AND c.c_preferred_cust_flag = 'Y'
)
SELECT
  i_category,
  cd_gender,
  SUM(sales_amount) AS total_sales,
  SUM(refund_amount) AS total_refunds,
  SUM(profit_amount) - SUM(refund_amount) AS net_profit,
  SUM(quantity_sold) AS total_qty_sold,
  SUM(quantity_returned) AS total_qty_returned,
  AVG(CASE WHEN sales_amount > 0 THEN discount_amount / sales_amount END) AS avg_discount_rate
FROM joined
GROUP BY i_category, cd_gender
HAVING SUM(sales_amount) > 10000
ORDER BY net_profit DESC
LIMIT 10
