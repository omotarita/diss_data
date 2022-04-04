from ast import keyword
from cmath import nan
from grapheme import startswith
import pandas as pd
import numpy as np
import credentials, tweepy, requests, json, csv, os, math, re, time

# Authenticate to Twitter
auth = tweepy.OAuthHandler(credentials.API_key, credentials.API_secret)
auth.set_access_token(credentials.access_token, credentials.access_secret)
api = tweepy.API(auth,wait_on_rate_limit=True)

client = tweepy.Client(credentials.bearer_token)

def authenticate():
    try:
        api.verify_credentials()
        print("Authentication Successful")
    except:
        print("Authentication Error")

    pass


def generate_queries(df, nft):
    query_list = []
    i = 1

    while i < 7:
        column_name = f"Column{i}"
        query = ""
        trailing = " OR "

        keyword_list = nft[column_name].tolist()

        n = 0
        
        for index in keyword_list:

            if keyword_list[n] != keyword_list[n]:
                #The most common method to check for NaN values is to check if the variable is equal to itself. If it is not, then it must be NaN value.
                n += 1

            elif '(n/a)' in keyword_list[n]:
                n += 1
            
            else:
                query = query + keyword_list[n] + " OR "
                n += 1


        #removes trailing " OR "
        if query.endswith(trailing):
            query = query[:-len(trailing)]

        query_list.append(query)

        i += 1


    #print(query_list)

        #swap whitespace for "%20"


    return query_list


def request_tweetcount(query_list, df):
    rw = 0
    gran = "hour"

    while rw < len(df):
        end = df.iloc[rw]['End Time']
        start = df.iloc[rw]['Start Time']

        end = end[:10] + "T" + end[11:]
        start = start[:10] + "T" + start[11:]

        end = end + "Z"
        start = start + "Z"


        n = 0
        for element in query_list:
            try:
                q = query_list[n]
                

                #API request
                result = client.get_recent_tweets_count(query = q, end_time = end, start_time = start, granularity = gran)
                meta = result[3]
                tweet_count = meta['total_tweet_count']



                partitioned_string = query_list[n].partition(" OR")
                df_column = partitioned_string[0]

                print(f"For {df_column} on {start}, the tweet count is {tweet_count}")

                #Add to dataframe
                df.loc[rw, df_column] = tweet_count

                n += 1

            except tweepy.TooManyRequests:
                time.sleep(60 * 15)
                continue
            except StopIteration:
                break

        #time.sleep(30)
        rw += 1

    return df

def concat_to_csv(df, output_file):

    df.to_csv(output_file, index=False)

    pass

def main():

    dataset_file = "tweetcount_files/tweet_counts_template.csv"

    #Comment out once tested
    #dataset_file = "tweetcount_template_pastweek_copy.csv"

    nft_file = "nft_keywords2.csv"
    output_file = "tweetcount_files/tweet_counts_data.csv"


    df = pd.read_csv(dataset_file)
    nft = pd.read_csv(nft_file)

    query_list = generate_queries(df, nft)
    request_tweetcount(query_list, df)
    concat_to_csv(df, output_file)

    '''test = client.get_recent_tweets_count(query = "Bored Ape Yacht Club", end_time = "2022-02-07T23:59:59Z", start_time = "2022-02-07T0:00:00Z", granularity = "day")

    meta = test[3]
    ttc_test = meta['total_tweet_count']

    print(ttc_test)'''
    
    pass

if __name__ == '__main__':
    main()
    