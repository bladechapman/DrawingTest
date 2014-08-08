//
//  ViewController.m
//  DrawingTest
//
//  Created by Darel Chapman on 7/19/14.
//  Copyright (c) 2014 Blade Chapman. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    BOOL _connectingLine;
    CGPoint _prevC;
    CGPoint _prevD;
    NSMutableArray *_points;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    red = 0.0/255.0;
    green = 0.0/255.0;
    blue = 0.0/255.0;
    brush = 3.0;
    opacity = 1.0;
    
    _connectingLine = NO;
    _points = [NSMutableArray array];
    
    [super viewDidLoad];
}

#pragma mark - UIButton Actions

- (IBAction)reset:(id)sender {
    self.mainImage.image = nil;
}

#pragma mark - Drawing implementation
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self.view];
    _points = [NSMutableArray array];
    [_points addObject:[NSValue valueWithCGPoint:[touch locationInView:self.view]]];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.view];

    //new style drawing
    [_points addObject:[NSValue valueWithCGPoint:[touch locationInView:self.view]]];

    NSMutableArray *smoothedPoints = [self calculateSmoothLinePoints];
    [self renderLinesPointsArray:smoothedPoints];

    lastPoint = currentPoint;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(!mouseSwiped) {
        UIGraphicsBeginImageContext(self.view.frame.size);
        [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];

        CGContextAddEllipseInRect(UIGraphicsGetCurrentContext(), CGRectMake([[touches anyObject] locationInView:self.view].x,
                                                                            [[touches anyObject] locationInView:self.view].y, brush, brush));
        CGContextDrawPath(UIGraphicsGetCurrentContext(), kCGPathFill);
        CGContextStrokePath(UIGraphicsGetCurrentContext());


        self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    _points = [NSMutableArray array];

    UIGraphicsBeginImageContext(self.mainImage.frame.size);
    [self.mainImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [self.tempDrawImage.image drawInRect:CGRectMake(self.tempDrawImage.center.x, self.tempDrawImage.center.y, self.view.frame.size.width/2, self.view.frame.size.height/2) blendMode:kCGBlendModeNormal alpha:1.0];
    self.mainImage.image = UIGraphicsGetImageFromCurrentImageContext();
    self.tempDrawImage.image = nil;
    UIGraphicsEndImageContext();
    
}


#pragma mark - complex drawing

- (void)renderLinesPointsArray:(NSMutableArray *)points
{
    UIGraphicsBeginImageContext(CGSizeMake(self.view.frame.size.width/2, self.view.frame.size.height/2));
    self.tempDrawImage.frame = CGRectMake(0, 0, self.view.frame.size.width/2, self.view.frame.size.height/2);
    [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width/2, self.view.frame.size.height/2)];

    self.tempDrawImage.center = [[points objectAtIndex:0] CGPointValue];

    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), [[points objectAtIndex:0] CGPointValue].x, [[points objectAtIndex:0] CGPointValue].y);

    for (int i = 1; i < [points count]; i++) {
        CGPoint addPoint = [[points objectAtIndex:i] CGPointValue];
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), addPoint.x, addPoint.y);
    }

    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, 1.0);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal);

    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
    [self.tempDrawImage setAlpha:opacity];
    UIGraphicsEndImageContext();
}

- (NSMutableArray *)calculateSmoothLinePoints
{
    if([_points count] > 2)
    {
        NSMutableArray *smoothedPoints = [NSMutableArray array];

        for (unsigned int i=2; i < [_points count]; ++i) {
            CGPoint prev2 = [[_points objectAtIndex:i - 2] CGPointValue];
            CGPoint prev1 = [[_points objectAtIndex:i - 1] CGPointValue];
            CGPoint cur = [[_points objectAtIndex:i] CGPointValue];

            CGPoint midPoint1 = CGPointMake((prev1.x + prev2.x)/2, (prev1.y + prev2.y)/2);
            CGPoint midPoint2 = CGPointMake((cur.x + prev1.x)/2, (cur.y + prev1.y)/2);

            int segmentDistance = 2;
            float distance = hypotf(midPoint1.x - midPoint2.x, midPoint1.y - midPoint2.y);
            int numberOfSegments = MIN(128, MAX(floorf(distance / segmentDistance), 32));

            float t = 0.0f;
            float step = 1.0f/numberOfSegments;
            for (NSUInteger j = 0; j < numberOfSegments; j++) {
                CGPoint newPoint;

                //use quad curve equation to add interpolated points
                newPoint.x = ((midPoint1.x * powf(1 - t, 2)) + (prev1.x * (2.0f * (1 - t) * t))) + (midPoint2.x * (t * t));
                newPoint.y = ((midPoint1.y * powf(1 - t, 2)) + (prev1.y * (2.0f * (1 - t) * t))) + (midPoint2.y * (t * t));

                [smoothedPoints addObject:[NSValue valueWithCGPoint:newPoint]];

                t += step;
            }

            CGPoint finalPoint = midPoint2;
            [smoothedPoints addObject:[NSValue valueWithCGPoint:finalPoint]];

            [_points removeObjectsInRange:NSMakeRange(0, [_points count] - 2)];


            return smoothedPoints;
        }
    }

    return nil;
}



@end
