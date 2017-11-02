//
//  SideRevealViewController.swift
//  iScan
//
//  Created by William Thompson on 5/18/17.
//  Copyright © 2017 J.W.Enterprises LLC. All rights reserved.
//

import UIKit

enum Direction {
    case Up
    case Down
    case Left
    case Right
}

struct SlideRevealViewHelper {
    static let menuWidth: CGFloat = 0.8
    static let iPadMenuWidth: CGFloat = 0.9
    static let percentThreshold: CGFloat = 0.3
    static let snapShotNumber = 12345

    static func calculateProgress(_ translationInView: CGPoint, viewBounds: CGRect, direction: Direction) -> CGFloat {
        let pointOnAxis: CGFloat
        let axisLength: CGFloat
        switch direction {
        case .Up, .Down:
            pointOnAxis = translationInView.y
            axisLength = viewBounds.height
        case .Left, .Right:
            pointOnAxis = translationInView.x
            axisLength = viewBounds.width
        }
        let movementOnAxis = pointOnAxis / axisLength
        let positiveMovementOnAxis: Float
        let positiveMovementOnAxisPercent: Float
        switch direction {
        case .Right, .Down:
            positiveMovementOnAxis = fmaxf(Float(movementOnAxis), 0.0)
            positiveMovementOnAxisPercent = fminf(positiveMovementOnAxis, 1.0)
            return CGFloat(positiveMovementOnAxisPercent)
        case .Up, .Left:
            positiveMovementOnAxis = fminf(Float(movementOnAxis), 0.0)
            positiveMovementOnAxisPercent = fmaxf(positiveMovementOnAxis, -1.0)
            return CGFloat(-positiveMovementOnAxisPercent)
        }
    }
    
    static func mapGestureStateToInteractor(_ gestureState: UIGestureRecognizerState, progress: CGFloat, interactor: SlideRevealViewInteractor?, triggerSegue: () -> Void) {
        guard let interactor = interactor else {
            return
        }
        switch gestureState {
        case .began:
            interactor.hasStarted = true
            triggerSegue()
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finish()
                : interactor.cancel()
        default:
            break
        }
    }
}

class SlideRevealViewInteractor: UIPercentDrivenInteractiveTransition {
    var hasStarted = false
    var shouldFinish = false
}

class SlideRevealViewAnimator: NSObject {
    
}

extension SlideRevealViewAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
            else {
            return
        }
        let containerView = transitionContext.containerView
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        if let snapshot = fromVC.view.snapshotView(afterScreenUpdates: false) {
            snapshot.tag = SlideRevealViewHelper.snapShotNumber
            snapshot.isUserInteractionEnabled = false
            snapshot.layer.shadowOpacity = 0.7
            containerView.insertSubview(snapshot, aboveSubview: toVC.view)
            fromVC.view.isHidden = true
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                    snapshot.center.x += UIScreen.main.bounds.width * SlideRevealViewHelper.iPadMenuWidth
                },
                               completion: { _ in
                                fromVC.view.isHidden = false
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
                )
            } else {
                UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                    snapshot.center.x += UIScreen.main.bounds.width * SlideRevealViewHelper.menuWidth
                },
                               completion: { _ in
                                fromVC.view.isHidden = false
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
                )
            }
            
        }
    }
}

class SlideRevealDismissAnimator: NSObject {
    
}

extension SlideRevealDismissAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            return
        }
        let containerView = transitionContext.containerView
        if let snapshot = containerView.viewWithTag(SlideRevealViewHelper.snapShotNumber) {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                snapshot.frame = CGRect(origin: CGPoint.zero, size: UIScreen.main.bounds.size)
            }, completion: { _ in
                let didTransitionComplete = !transitionContext.transitionWasCancelled
                if didTransitionComplete {
                    containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
                    snapshot.removeFromSuperview()
                }
                transitionContext.completeTransition(didTransitionComplete)
                
                }
            )
        }
    }
}

