SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_return_amt * (1 + wr.wr_return_tax / 100) AS return_amt_inc_tax_calc,
       CASE WHEN wr.wr_return_quantity > 5 THEN 'Bulk Return' WHEN wr.wr_return_quantity > 0 THEN 'Single Item Return' ELSE 'No Return' END AS return_category,
       (wr.wr_return_amt - wr.wr_return_tax) AS net_return_before_tax,
       (wr.wr_return_amt_inc_tax - wr.wr_return_tax) AS net_return_excluding_tax,
       (wr.wr_return_amt_inc_tax + wr.wr_fee) AS total_return_cost,
       (wr.wr_return_amt_inc_tax + wr.wr_fee - wr.wr_refunded_cash) AS net_loss_calc
FROM web_returns wr
JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_birth_year = 1926
  AND wr.wr_returned_date_sk = 2451758
