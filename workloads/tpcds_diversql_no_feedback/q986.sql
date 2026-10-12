WITH
  sr AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_item_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_addr_sk,
      sr.sr_store_sk,
      sr.sr_reason_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss AS sr_net_loss,
      r.r_reason_desc,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      ca.ca_state,
      s.s_store_name,
      td_ret.t_hour AS ret_hour,
      td_ret.t_am_pm AS ret_am_pm,
      ss.ss_sales_price,
      ss.ss_net_paid,
      ss.ss_net_profit,
      cd.cd_gender,
      td_sold.t_hour AS sold_hour,
      td_sold.t_am_pm AS sold_am_pm
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td_ret ON sr.sr_return_time_sk = td_ret.t_time_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td_sold ON ss.ss_sold_time_sk = td_sold.t_time_sk
    WHERE td_ret.t_hour = 9
      AND td_ret.t_am_pm = 'AM'
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state = 'WA'
      AND r.r_reason_desc LIKE '%defective%'
      AND cd.cd_gender = 'M'
      AND ss.ss_sales_price > 50
  ),
  cr AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_item_sk,
      cr.cr_refunded_customer_sk,
      cr.cr_refunded_cdemo_sk,
      cr.cr_refunded_addr_sk,
      cr.cr_returning_customer_sk,
      cr.cr_returning_cdemo_sk,
      cr.cr_returning_addr_sk,
      cr.cr_reason_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss AS cr_net_loss,
      r.r_reason_desc,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      ca.ca_state,
      td.t_hour,
      td.t_am_pm
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour = 15
      AND td.t_am_pm = 'PM'
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state = 'WA'
      AND r.r_reason_desc LIKE '%defective%'
  ),
  full_join AS (
    SELECT
      COALESCE(sr.r_reason_desc, cr.r_reason_desc) AS reason_desc,
      COALESCE(sr.i_category, cr.i_category) AS category,
      COALESCE(sr.i_brand, cr.i_brand) AS brand,
      COALESCE(sr.s_store_name, 'UNKNOWN') AS store_name,
      COALESCE(sr.ret_hour, cr.t_hour) AS hour,
      COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) AS total_net_loss,
      COALESCE(sr.sr_return_quantity, 0) + COALESCE(cr.cr_return_quantity, 0) AS total_return_qty,
      COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0) AS total_return_amount,
      COALESCE(sr.ss_sales_price, 0) AS sales_price,
      COALESCE(sr.ss_net_paid, 0) AS net_paid,
      COALESCE(sr.ss_net_profit, 0) AS net_profit
    FROM sr
    FULL OUTER JOIN cr ON sr.sr_reason_sk = cr.cr_reason_sk
  ),
  unioned AS (
    SELECT reason_desc, category, brand, store_name, hour,
           total_net_loss, total_return_qty, total_return_amount,
           sales_price, net_paid, net_profit
    FROM full_join
    WHERE hour = 9
    UNION
    SELECT reason_desc, category, brand, store_name, hour,
           total_net_loss, total_return_qty, total_return_amount,
           sales_price, net_paid, net_profit
    FROM full_join
    WHERE hour = 15
  )
SELECT
  reason_desc,
  category,
  brand,
  store_name,
  hour,
  SUM(total_net_loss) AS sum_net_loss,
  AVG(total_return_qty) AS avg_return_qty,
  COUNT(*) AS cnt_rows,
  MIN(total_return_amount) AS min_return_amount,
  MAX(total_return_amount) AS max_return_amount,
  SUM(sales_price) AS sum_sales_price,
  SUM(net_paid) AS sum_net_paid,
  SUM(net_profit) AS sum_net_profit
FROM unioned
GROUP BY
  reason_desc,
  category,
  brand,
  store_name,
  hour
HAVING SUM(total_net_loss) > 0
ORDER BY sum_net_loss DESC
OFFSET 0 LIMIT 100
