module Parser where

import Protolude hiding (one, many, optional)

import           Common.ParserT
import qualified Lexer.Token as Tk
import           Parser.AST
import           Parser.Types
import           Utils ((<<))

parseProgram :: Parser Program
parseProgram = Program <$> many parseStmt

parseStmt :: Parser Stmt
parseStmt = choose
  [ parseLetStmt
  , parseReturnStmt
  , parseExprStmt
  ]

parseIdent :: Parser Ident
parseIdent = next >>= go
  where
  go (Tk.Ident name) = return $ Ident name
  go _ = fail "fail to parse an identifier"

parseLetStmt :: Parser Stmt
parseLetStmt = do
  atom Tk.Let
  ident <- parseIdent
  atom Tk.Assign
  expr <- parseExpr
  atom Tk.SemiColon
  return $ LetStmt ident expr

parseReturnStmt :: Parser Stmt
parseReturnStmt = do
  atom Tk.Return
  expr <- parseExpr
  atom Tk.SemiColon
  return $ ReturnStmt expr

parseExprStmt :: Parser Stmt
parseExprStmt = ExprStmt <$> do
  expr <- parseExpr
  optional $ atom Tk.SemiColon
  return expr

parseExpr :: Parser Expr
parseExpr = choose
  [ parseParenExpr
  , parseLitExpr
  , parseIdentExpr
  , parsePrefixExpr
  ]

parseParenExpr :: Parser Expr
parseParenExpr = do
  atom Tk.LParen
  expr <- parseExpr
  atom Tk.RParen
  return expr

parseLiteral :: Parser Literal
parseLiteral = next >>= go
  where
  go (Tk.IntLiteral i) = return $ IntLiteral i
  go (Tk.BoolLiteral b) = return $ BoolLiteral b
  go _ = fail "fail to parse a literal"

parsePrefixExpr :: Parser Expr
parsePrefixExpr = do
  tkn <- choose [atom Tk.Plus, atom Tk.Minus, atom Tk.Not]
  case tkn of
    Tk.Plus -> PrefixExpr PrefixPlus <$> parseExpr
    Tk.Minus -> PrefixExpr PrefixMinus <$> parseExpr
    Tk.Not -> PrefixExpr Not <$> parseExpr
    _ -> fail "fail to parse a prefix expr"

parseInfixExpr :: Parser Expr -> Parser Expr
parseInfixExpr left = undefined

parseLitExpr :: Parser Expr
parseLitExpr = LitExpr <$> parseLiteral

parseIdentExpr :: Parser Expr
parseIdentExpr = IdentExpr <$> parseIdent

finish :: Parser ()
finish = next >>= go
  where
  go Tk.EOF = return ()
  go tkn = fail $ "unexpected token: " ++ show tkn

parse :: [Tk.Token] -> Program
parse = execParser (parseProgram << finish)
