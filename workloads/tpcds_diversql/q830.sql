WITH
  -- Catalog sales profit per customer (items whose description contains 'large' or 'medium')
  cs AS (
    SELECT
      cs.cs_bill_customer_sk AS customer_sk,
      cs.cs_sold_date_sk      AS date_sk,
      SUM(cs.cs_net_profit)   AS profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)large|medium')
    GROUP BY cs.cs_bill_customer_sk, cs.cs_sold_date_sk
  ),

  -- Web sales profit per customer (same item filter)
  ws AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      ws.ws_sold_date_sk    AS date_sk,
      SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)large|medium')
    GROUP BY ws.ws_bill_customer_sk, ws.ws_sold_date_sk
  ),

  -- Union of both profit sources (deduped)
  profit_union AS (
    SELECT * FROM cs
    UNION
    SELECT * FROM ws
  ),

  -- Store returns that mention the word "price" in the reason
  returns_filtered AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_return_time_sk,
      sr.sr_return_amt,
      r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price')
      AND r.r_reason_desc LIKE '%price%'
  ),

  -- Customers that have profit but no matching return (EXCEPT on key set)
  customers_without_returns AS (
    SELECT DISTINCT customer_sk FROM profit_union
    EXCEPT
    SELECT DISTINCT sr_customer_sk FROM returns_filtered
  ),

  -- Profit rows limited to customers without returns
  profit_filtered AS (
    SELECT pu.customer_sk, pu.date_sk, pu.profit
    FROM profit_union pu
    JOIN customers_without_returns cwr ON pu.customer_sk = cwr.customer_sk
  ),

  -- Full outer join between returns and time dimension (keeps unmatched rows on both sides)
  full_returns AS (
    SELECT
      rf.sr_customer_sk,
      rf.sr_return_amt,
      rf.r_reason_desc,
      td.t_hour
    FROM returns_filtered rf
    FULL OUTER JOIN time_dim td ON rf.sr_return_time_sk = td.t_time_sk
  )

SELECT
  c.c_customer_id,
  CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
  COALESCE(pf.profit, 0)                     AS total_profit,
  COALESCE(fr.sr_return_amt, 0)              AS return_amount,
  fr.t_hour,
  CASE
    WHEN fr.r_reason_desc IS NOT NULL THEN regexp_extract(fr.r_reason_desc, '(\\w+)', 1)
    ELSE NULL
  END                                          AS reason_first_word
FROM profit_filtered pf
LEFT JOIN full_returns fr ON pf.customer_sk = fr.sr_customer_sk
JOIN customer c ON pf.customer_sk = c.c_customer_sk
WHERE c.c_email_address LIKE '%@example.com'
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
