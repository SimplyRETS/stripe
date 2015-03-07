{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
module Test.Subscription where

import           Data.Either
import           Control.Monad
import           Data.Maybe

import           Test.Hspec
import           Test.Util

import           Web.Stripe
import           Web.Stripe.Subscription
import           Web.Stripe.Customer
import           Web.Stripe.Token
import           Web.Stripe.Plan
import           Web.Stripe.Coupon

subscriptionTests :: StripeConfig -> Spec
subscriptionTests config = do
  describe "Subscription tests" $ do
    it "Succesfully creates a Subscription" $ do
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        sub <- createSubscription cid planid []
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully creates a Subscription via a token" $ do
      planid <- makePlanId
      sub <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        Token { tokenId = tokenid } <- createCardToken cn em ey cvc
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        result <- createSubscriptionWithTokenId cid planid tokenid []
        void $ deletePlan planid
        void $ deleteCustomer cid
        return result
      sub `shouldSatisfy` isRight
    it "Succesfully retrieves a Subscription" $ do
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        Subscription { subscriptionId = sid } <- createSubscription cid planid []
        sub <- getSubscription cid sid
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully retrieves a Subscription expanded" $ do
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        Subscription { subscriptionId = sid } <- createSubscription cid planid []
        sub <- getSubscriptionExpandable cid sid ["customer"]
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully retrieves a Customer's Subscriptions expanded" $ do
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        void $ createSubscription cid planid []
        sub <- getSubscriptionsExpandable cid Nothing Nothing Nothing ["data.customer"]
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully retrieves a Customer's Subscriptions" $ do
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        void $ createSubscription cid planid []
        sub <- getSubscriptions cid Nothing Nothing Nothing 
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
    it "Succesfully updates a Customer's Subscriptions" $ do
      planid <- makePlanId
      secondPlanid <- makePlanId
      couponid <- makeCouponId
      result <- stripe config $ do
        Coupon { } <-
          createCoupon
             (Just couponid)
             Once
             (Just $ AmountOff 1)
             (Just USD)
             Nothing
             Nothing
             Nothing
             Nothing
             []
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        void $ createPlan secondPlanid
                        0 -- free plan
                        USD
                        Year
                        "second sample plan"
                        []
        Subscription { subscriptionId = sid } <- createSubscription cid planid []
        _ <- updateSubscription cid sid (Just couponid) Nothing [("hi","there")]
        sub <- updateSubscription cid sid (Just couponid) (Just secondPlanid) [("hi","there")]
        void $ deletePlan planid
        void $ deletePlan secondPlanid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
      let Right Subscription {..} = result
      subscriptionMetaData `shouldBe` [("hi", "there")]
      subscriptionDiscount `shouldSatisfy` isJust
    it "Succesfully cancels a Customer's Subscription" $ do
      planid <- makePlanId
      result <- stripe config $ do
        Customer { customerId = cid } <- createEmptyCustomer
        void $ createPlan planid
                        0 -- free plan
                        USD
                        Month
                        "sample plan"
                        []
        Subscription { subscriptionId = sid } <- createSubscription cid planid []
        sub <- cancelSubscription cid sid False
        void $ deletePlan planid
        void $ deleteCustomer cid
        return sub
      result `shouldSatisfy` isRight
      let Right Subscription {..} = result
      subscriptionStatus `shouldBe` Canceled
  where
    cn  = CardNumber "4242424242424242"
    em  = ExpMonth 12
    ey  = ExpYear 2015
    cvc = CVC "123"

