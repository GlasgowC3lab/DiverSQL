WITH ticket_set AS (
    SELECT COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
           ss.ss_net_paid,
           sr.sr_return_amt,
           d_sales.d_year AS sales_year,
           d_ret.d_year AS return_year,
           i.i_category
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN item i ON COALESCE(ss.ss_item_sk, sr.sr_item_sk) = i.i_item_sk
    WHERE (d_sales.d_year = 2001 OR d_ret.d_year = 2001)
      AND i.i_category = 'Sports'
),
web_tickets AS (
    SELECT ws.ws_order_number AS ticket_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
diff_tickets AS (
    SELECT ticket_number FROM ticket_set
    EXCEPT
    SELECT ticket_number FROM web_tickets
)
SELECT ts.ticket_number,
       ts.sales_year,
       ts.return_year,
       ts.ss_net_paid,
       ts.sr_return_amt
FROM ticket_set ts
JOIN diff_tickets dt ON ts.ticket_number = dt.ticket_number
ORDER BY ts.ticket_number
LIMIT 100
