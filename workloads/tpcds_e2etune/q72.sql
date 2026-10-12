WITH returns_agg AS (
  SELECT
    d.d_year,
    d.d_moy AS month_of_year,
    r.r_reason_desc,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(ca.ca_gmt_offset) AS avg_gmt_offset
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 2000 AND 2001
    AND ca.ca_state = 'CA'
    AND r.r_reason_desc LIKE '%damaged%'
  GROUP BY d.d_year, d.d_moy, r.r_reason_desc
  HAVING SUM(wr.wr_net_loss) > 500
),
call_center_agg AS (
  SELECT
    d_cc.d_year,
    cc.cc_division,
    SUM(cc.cc_employees) AS total_employees,
    COUNT(*) AS call_center_count
  FROM call_center cc
  JOIN date_dim d_cc ON cc.cc_open_date_sk = d_cc.d_date_sk
  WHERE cc.cc_gmt_offset = -5.00
    AND cc.cc_division = 3
    AND d_cc.d_year BETWEEN 2000 AND 2001
  GROUP BY d_cc.d_year, cc.cc_division
),
ranked_returns AS (
  SELECT
    ra.*, 
    RANK() OVER (PARTITION BY ra.d_year, ra.month_of_year ORDER BY ra.total_net_loss DESC) AS reason_rank
  FROM returns_agg ra
)
SELECT
  rr.d_year,
  rr.month_of_year,
  cc.cc_division,
  rr.r_reason_desc,
  rr.total_net_loss,
  rr.avg_return_amt,
  rr.total_returns,
  rr.distinct_customers,
  rr.avg_gmt_offset,
  cc.total_employees,
  cc.call_center_count,
  rr.reason_rank
FROM ranked_returns rr
JOIN call_center_agg cc ON rr.d_year = cc.d_year
WHERE rr.reason_rank <= 5
ORDER BY rr.d_year, rr.month_of_year, rr.reason_rank
