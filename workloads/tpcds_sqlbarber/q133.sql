SELECT s.s_store_name, SUM(sr.sr_return_amt) AS total_return_amount FROM store s JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk WHERE s.s_state = 'NE' GROUP BY s.s_store_name
