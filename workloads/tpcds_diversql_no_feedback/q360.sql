/* Goal: Identify customers who both purchased and later returned items in the 'Sports' category with high price and significant return quantity. */
SELECT c_customer_id
FROM (
    SELECT DISTINCT c.c_customer_id
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'
      AND i.i_current_price > 100
) 
INTERSECT
SELECT c_customer_id
FROM (
    SELECT DISTINCT c.c_customer_id
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'
      AND wr.wr_return_quantity > 5
)
ORDER BY c_customer_id
