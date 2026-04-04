import { ReactNode } from "react";

export const NoWhitespace = ({ children }: { children: ReactNode }) => {
  return (
    <span
      style={{
        position: "relative",
        display: "inline-block",
        whiteSpace: "nowrap",
      }}
    >
      {children}
    </span>
  );
};
