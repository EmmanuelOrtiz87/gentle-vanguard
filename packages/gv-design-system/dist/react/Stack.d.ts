import { type HTMLAttributes, type ReactNode } from 'react';
import './Stack.css';
export type StackDirection = 'row' | 'column' | 'row-reverse' | 'column-reverse';
export type StackAlign = 'start' | 'center' | 'end' | 'stretch' | 'baseline';
export type StackJustify = 'start' | 'center' | 'end' | 'between' | 'around' | 'evenly';
export type StackWrap = 'wrap' | 'nowrap' | 'wrap-reverse';
export type StackGap = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | 12 | 16 | 20 | 24;
export interface StackProps extends HTMLAttributes<HTMLDivElement> {
    direction?: StackDirection;
    align?: StackAlign;
    justify?: StackJustify;
    wrap?: StackWrap;
    gap?: StackGap;
    inline?: boolean;
    as?: 'div' | 'section' | 'article' | 'header' | 'footer' | 'nav' | 'main' | 'aside';
    children: ReactNode;
}
/**
 * Stack — Gentle-Vanguard v2 flex layout primitive.
 * Thin wrapper over CSS flexbox with token-based gap scale.
 *
 * @example
 *   <Stack direction="row" gap={4} align="center">
 *     <Logo />
 *     <Title>Dashboard</Title>
 *   </Stack>
 *   <Stack direction="column" gap={6}>
 *     <Header />
 *     <Body />
 *   </Stack>
 */
export declare const Stack: import("react").ForwardRefExoticComponent<StackProps & import("react").RefAttributes<HTMLDivElement>>;
//# sourceMappingURL=Stack.d.ts.map